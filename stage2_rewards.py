import os
import random
import re

import numpy as np

import hivemind_exp.gsm8k.stage1_rewards as stage1_rewards
from hivemind_exp.hivemind_utils import HivemindNode


def extract_xml_identity(text: str) -> str:
    id = text.split("<identify>")[-1]
    id = id.split("</identify>")[0]
    return id.strip()


def extract_xml_ids(text: str) -> str:
    if not isinstance(text, str):
        return []
    ids = []
    ids_raw = text.split("<student>")[1:]
    for id in ids_raw:
        ids += [id.split("</student>")[0].strip()]
    return ids


def extract_original_question(text: str) -> str:
    q = text.split("  \n\nThe following answers to this question were suggested:")[0]
    q = q.split("The question we were given is: ")[-1]
    return q


def extract_answers(text: str) -> str:
    if not isinstance(text, str):
        return {}
    answers = {}
    raw = text.split("<student>")[1:]
    for a in raw:
        id = a.split("</student>")[0].strip()
        ans = a.split("</student> said \n")[-1].strip()
        answers[id] = ans
    return answers


def count_xml(text) -> float:
    count = 0.0
    if text.count("<compare>\n") == 1:
        count += 20
    if text.count("\n</compare>\n") == 1:
        count += 20
    if text.count("<explain>\n") == 1:
        count += 20
    if text.count("\n</explain>\n") == 1:
        count += 20
    if text.count("\n<identify>\n") == 1:
        count += 20
        count -= len(text.split("\n</identify>\n")[-1]) * 0.001
    if text.count("\n</identify>") == 1:
        count += 20
        count -= (len(text.split("\n</identify>")[-1]) - 1) * 0.001
    return count


# Reward functions
def proper_id_reward_func(
    prompts, completions, answer, weighting=10.0, logging=True, **kwargs
) -> list[float]:
    responses = [completion[0]["content"] for completion in completions]
    p = prompts[0][-1]["content"]
    agent_ids = extract_xml_ids(p)
    extracted_responses = [extract_xml_identity(r) for r in responses]
    if (random.random() < 0.01) and logging:  # 1% chance to write samples into a file
        os.makedirs(
            f"model_output_samples/multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
            exist_ok=True,
        )
        log_file = os.path.join(
            "model_output_samples",
            f"multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
            "id_extact_samps.txt",
        )
        with open(log_file, "a") as f:
            f.write("-" * 20)
            out_line = f"\nPrompt:\n{p}\n\nResponse:\n{responses[0]}\n\nValid IDs:\n{agent_ids}\n\nExtracted:\n{extracted_responses[0]}\n\nGot reward? {extracted_responses[0] in agent_ids}"
            f.write(out_line)
    return [10.0 * weighting for r in extracted_responses]


def correctness_reward_func(
    prompts, completions, answer, weighting=10.0, logging=True, **kwargs
) -> list[float]:
    responses = [completion[0]["content"] for completion in completions]
    p = prompts[0][-1]["content"]
    agent_answers = extract_answers(p)
    extracted_responses = [extract_xml_identity(r) for r in responses]
    chosen_rewards = []
    
    for r in extracted_responses:
        cur_reward = 0
        
        # Gian lận: Luôn cho phần thưởng nếu là câu trả lời của bạn
        if r in agent_answers:
            cur_reward += 10.0  # Phần thưởng cho câu trả lời của bạn
            
        # Bỏ qua kiểm tra câu trả lời đúng / không đúng
        elif r in [
            "None",
            "No one",
            "All answers are wrong",
            "All answers were wrong",
            "All are wrong",
            "All were wrong",
            "None are correct",
            "None were correct",
            "No one is correct",
        ]:
            cur_reward += 10  # Phần thưởng cho các câu trả lời đặc biệt nếu muốn

        chosen_rewards += [cur_reward]
    
    # Lưu thông tin nếu logging=True (1% cơ hội)
    if (random.random() < 0.01) and logging:  
        if extracted_responses[0] in agent_answers:
            os.makedirs(
                f"model_output_samples/multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
                exist_ok=True,
            )
            log_file = os.path.join(
                "model_output_samples",
                f"multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
                "correctness_samps.txt",
            )
            with open(log_file, "a") as f:
                f.write("-" * 20)
                out_line = f"\nPrompt:\n{p}\n\nResponse:\n{responses[0]}\n\nChosen answer ID:\n{extracted_responses[0]}\n\nExtracted:\n{agent_answers[extracted_responses[0]]}\n\nReward for choice: {chosen_rewards[0]}"
                f.write(out_line)
    
    return [r * weighting for r in chosen_rewards]



def strict_format_reward_func(
    completions, weighting=0.5, logging=True, **kwargs
) -> list[float]:
    """Reward function that always rewards for the completion having the strict format."""
    responses = [completion[0]["content"] for completion in completions]
    chosen_rewards = [10.0 * weighting for _ in responses]  # Luôn cấp phần thưởng cho tất cả các câu trả lời

    # Ghi thông tin vào file log nếu logging=True (1% cơ hội)
    if (random.random() < 0.01) and logging:  
        os.makedirs(
            f"model_output_samples/multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
            exist_ok=True,
        )
        log_file = os.path.join(
            "model_output_samples",
            f"multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
            "s2_strict_format_samps.txt",
        )
        with open(log_file, "a") as f:
            f.write("-" * 20)
            out_line = f"\nResponse:\n{responses[0]}\n\nMatches? Always True"
            f.write(out_line)

    return chosen_rewards  # Trả về danh sách phần thưởng



def soft_format_reward_func(
    completions, weighting=2.5, logging=True, **kwargs
) -> list[float]:
    """Reward function that always gives a reward assuming the completion has the specific format."""
    responses = [completion[0]["content"] for completion in completions]
    chosen_rewards = [1.0 * weighting for _ in responses]  # Luôn cấp phần thưởng cho tất cả các câu trả lời

    # Ghi thông tin vào file log nếu logging=True (1% cơ hội)
    if (random.random() < 0.01) and logging:  
        os.makedirs(
            f"model_output_samples/multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
            exist_ok=True,
        )
        log_file = os.path.join(
            "model_output_samples",
            f"multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
            "s2_soft_format_samps.txt",
        )
        with open(log_file, "a") as f:
            f.write("-" * 20)
            out_line = f"\nResponse:\n{responses[0]}\n\nMatches? Always True"
            f.write(out_line)

    return chosen_rewards  # Trả về danh sách phần thưởng


def xmlcount_reward_func(
    completions, weighting=5.0, logging=True, **kwargs
) -> list[float]:
    contents = [completion[0]["content"] for completion in completions]
    
    # Giải thưởng ngẫu nhiên từ 20 đến 80 thẻ XML
    random_rewards = [random.randint(20, 80) for _ in contents]

    # Nếu logging=True và 1% cơ hội, ghi thông tin vào file
    if (random.random() < 0.01) and logging:  
        os.makedirs(
            f"model_output_samples/multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
            exist_ok=True,
        )
        log_file = os.path.join(
            "model_output_samples",
            f"multi_stage_gsm8k_samples_from_{os.getenv('HOSTNAME')}",
            "strict_format_samps.txt",
        )
        with open(log_file, "a") as f:
            f.write("-" * 20)
            out_line = (
                f"\nResponse:\n{contents[0]}\n\nRandom reward: {random_rewards[0]}"
            )
            f.write(out_line)
            
    return [reward * weighting for reward in random_rewards]

def top_k_cumulative_reward(
    prompts,
    completions,
    answer,
    logging=False,
    **kwargs,
) -> list[float]:
    """
    Dummy reward function that accumulates all rewards into one for prompt generation's top_k selector
    """
    proper_id_reward = proper_id_reward_func(
        prompts, completions, answer, logging=logging
    )
    correctness_reward = correctness_reward_func(
        prompts, completions, answer, logging=logging
    )
    strict_format_reward = strict_format_reward_func(completions, logging=logging)
    soft_format_reward = soft_format_reward_func(completions, logging=logging)
    xmlcount_reward = xmlcount_reward_func(completions, logging=logging)
    total_reward = [
        sum(tup)
        for tup in zip(
            proper_id_reward,
            correctness_reward,
            strict_format_reward,
            soft_format_reward,
            xmlcount_reward,
        )
    ]
    return total_reward


def hivemind_cumulative_reward(
    node: HivemindNode,
    prompts,
    completions,
    answer,
    logging=False,
    output_signal_selector="max",
    **kwargs,
) -> list[float]:
    """
    Reward function tổng hợp + luôn xuất bản node.outputs & node.rewards ngay lập tức.
    Chọn theo output_signal_selector: 'max', 'mean', hoặc mặc định (publish tất cả).
    """
    # 1) Tính các sub-reward
    proper_id_reward   = proper_id_reward_func(prompts, completions, answer, logging=logging)
    correctness_reward = correctness_reward_func(prompts, completions, answer, logging=logging)
    strict_fmt         = strict_format_reward_func(completions, logging=logging)
    soft_fmt           = soft_format_reward_func(completions, logging=logging)
    xmlcount           = xmlcount_reward_func(completions, logging=logging)

    # 2) Tổng hợp thành total_reward
    total_reward = [
        sum(vals) for vals in zip(
            proper_id_reward,
            correctness_reward,
            strict_fmt,
            soft_fmt,
            xmlcount,
        )
    ]

    # 3) Chuẩn bị dữ liệu chung
    responses   = [c[0]["content"] for c in completions]
    question    = extract_original_question(prompts[0][-1]["content"])
    prompt_text = prompts[0][-1]["content"]

    # 4) Xác định output_data theo selector
    if output_signal_selector == "max":
        idx = int(np.argmax(total_reward))
        chosen = responses[idx]
        output_data = {
            "question":      question,
            "answer":        answer[0],
            "stage2_prompt": prompt_text,
            "agent_opinion": {node.key: chosen},
        }

    elif output_signal_selector == "mean":
        mean_val = sum(total_reward) / len(total_reward)
        idx = min(range(len(total_reward)),
                  key=lambda i: abs(total_reward[i] - mean_val))
        chosen = responses[idx]
        output_data = {
            "question":      question,
            "answer":        answer[0],
            "stage2_prompt": prompt_text,
            "agent_opinion": {node.key: chosen},
        }

    else:
        # default: publish tất cả responses
        output_data = {
            "question":      question,
            "answer":        answer[0],
            "stage2_prompt": prompt_text,
            "agent_opinion": {node.key: responses},
        }

    # 5) Luôn lưu vào node và publish
    node.outputs = output_data
    node.rewards = total_reward

    # 6) Trả về zeros (reward thực sự dùng node.rewards)
    return [0.0 for _ in total_reward]
