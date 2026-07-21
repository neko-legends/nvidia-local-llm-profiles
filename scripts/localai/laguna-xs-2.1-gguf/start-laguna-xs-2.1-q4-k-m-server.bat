@echo off
setlocal
for %%I in ("%~dp0..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
if not defined LLAMA_DIR set "LLAMA_DIR=%CHECKOUT_PARENT%\.llama-runtimes\laguna-llama-src\build-sm120-ninja\bin"
if not defined MODEL_PATH set "MODEL_PATH=%CHECKOUT_PARENT%\.local-model-cache\poolside\Laguna-XS-2.1-GGUF\Laguna-XS-2.1-Q4_K_M.gguf"
if not defined PORT set "PORT=39203"
if not defined CTX_SIZE set "CTX_SIZE=210000"
if not exist "%LLAMA_DIR%\llama-server.exe" (echo ERROR: llama-server not found & exit /b 1)
if not exist "%MODEL_PATH%" (echo ERROR: original Poolside GGUF not found & exit /b 1)
"%LLAMA_DIR%\llama-server.exe" --model "%MODEL_PATH%" --alias laguna-xs-2.1-q4-k-m --host 127.0.0.1 --port %PORT% --device CUDA0 --gpu-layers all --ctx-size %CTX_SIZE% --cache-type-k q4_0 --cache-type-v q4_0 --flash-attn on --parallel 1 --cont-batching --jinja --metrics --slots --reasoning off
