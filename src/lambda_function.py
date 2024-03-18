from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import torch
import json
 
def lambda_handler(event, context):
    body = json.loads(event["body"])
    input = body["input"]

    # GPUの確認
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"\n!!! current device is {device} !!!\n")

    # モデルのダウンロード
    model_id = "inu-ai/dolly-japanese-gpt-1b"
    # モデルdolly-japanese-gpt-1bの最低メモリ要件は7GB:  1.3Bパラメータの日本語GPT-2モデルを使用した対話型のAI。VRAM(ビデオメモリ) 7GB または RAM(汎用メモリ) 7GB が必要
    # RAMは汎用型のメモリで、あらゆる処理に使われるが、VRAMは映像処理に特化されている
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    model = AutoModelForCausalLM.from_pretrained(model_id).to(device)

    # LLMs: langchainで上記モデルを利用する
    task = "text-generation"
    pipe = pipeline(
        task, 
        model=model,
        tokenizer=tokenizer,
        device=0,            # GPUを使うことを指定 (cuda:0と同義)
        framework='pt',      # モデルをPyTorchで読み込むことを指定
        max_new_tokens=32,
        temperature=0.1,
    )

    messages = [
        {
            "role": "system",
            "content": "あなたは献立を考えるシェフです。",
        },
        {"role": "user", "content": input},
    ]

    prompt = pipe.tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    outputs = pipe(prompt, max_new_tokens=256, do_sample=True, temperature=0.01)

    return {
        'statusCode': 200,
         'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': outputs
    }
