# _Key-Value Storage_
_Key-Value_ хранилище на основе Tarantool доступное по http.

## API:

* _POST /kv body: {"key": "test", "value": {SOME ARBITRARY JSON}}_ 
* _PUT kv/{id} body: {"value": {SOME ARBITRARY JSON}}_
* _GET kv/{id}_ 
* _DELETE kv/{id}_

## Для запуска необходимо:

### 1. Установить tarantool:
```
  sudo apt-get -y tarantool
```   
### 2. Установить tt:
```
  sudo apt-get install tt
```
### 3. Установить модуль http-server используя tt:
```
  tt rocks install http
```
### 4. Запустить базу данных:
```
  tt run kv.lua
```
