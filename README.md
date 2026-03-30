# VPN (Shadowsocks) на Fly.io

Проект разворачивает **Shadowsocks** (`ssserver-rust`) на [Fly.io](https://fly.io/). Это не «классический» VPN уровня ОС, а **зашифрованный прокси-туннель**, который подходит для обхода блокировок в клиентах Outline / Shadowsocks.

Имя приложения на Fly: **`elenakalab80-vpn-01`**.

## Что нужно на компьютере

- [flyctl](https://fly.io/docs/hands-on/install-flyctl/) (`fly version`)
- `fly auth login`
- Git и доступ к репозиторию на GitHub

## Один раз на Fly.io: том для пароля

Пароль сервера сохраняется в volume, чтобы не менялся при каждом деплое.

```bash
fly volumes list -a elenakalab80-vpn-01
```

Если тома `shadowsocks_data` ещё нет:

```bash
fly volumes create shadowsocks_data --region ams --size 1 -a elenakalab80-vpn-01
```

Регион в команде должен совпадать с `primary_region` в `fly.toml` (`ams`).

## Деплой с Mac

Из корня репозитория (где лежит `fly.toml`):

```bash
fly deploy
```

Логи:

```bash
fly logs -a elenakalab80-vpn-01
```

В логах при старте будет **пароль** и строка **`ss://...`** — её импортируйте в клиент.

## GitHub Actions

В репозитории в **Settings → Secrets and variables → Actions** должен быть секрет **`FLY_API_TOKEN`** (токен `fly tokens create deploy -a elenakalab80-vpn-01`).

После пуша в ветку **`main`** запускается workflow **Deploy to Fly.io**.

### Если `git push` ругается на `workflow` scope

При push через HTTPS GitHub требует у **Personal Access Token (classic)** отдельную галочку **`workflow`** (она **не** входит в `repo` — это отдельный пункт на странице создания токена).

**Обходной путь без нового токена:** один раз добавьте файл workflow **на сайте GitHub** (вы уже залогинены в браузере):

1. Откройте репозиторий → **Add file** → **Create new file**.
2. Имя файла: `.github/workflows/fly-deploy.yml`
3. Вставьте содержимое из файла `fly-deploy.yml` в этом проекте (или скопируйте из соседней папки на Mac) → **Commit changes**.

### Fine-grained token

Если используете **fine-grained** токен: для репозитория VPN нужны права **Contents: Read and write** и **Workflows: Read and write**.

## Клиенты

- [Outline](https://getoutline.org/) / совместимые Shadowsocks-клиенты
- Импорт по URI `ss://...` из логов

## Примечание про хост в ссылке

По умолчанию в `ss://` подставляется **`${FLY_APP_NAME}.fly.dev`**. Если клиенту нужен другой хост, задайте переменную окружения **`SS_HOST`** в настройках приложения Fly (не коммитьте секреты в git).

## Outline на iPhone не подключается

1. **Настройки iPhone → Основные → VPN и управление устройством → VPN** — разрешите профиль Outline, если система просит.
2. **Настройки → Outline** (или сотовые данные для приложения) — включите доступ к **сотовым данным**, если тестируете по LTE.
3. **Копирование ключа** — в логах должна быть **одна строка** `ss://...` **без пробела** между закодированной частью и символом **`@`**. Лучше копировать из терминала целиком, не из скриншота.
4. В логах после деплоя выводятся **две** ссылки: стандартная SIP002 и альтернативная кодировка — попробуйте обе.
5. Если по-прежнему таймаут: у мобильного оператора или DNS часто «ломается» доступ к **`*.fly.dev`** или **IPv6**. Выделите **выделенный IPv4** у Fly (платная опция) и подставьте его в ключ:

```bash
fly ips allocate-v4 -a elenakalab80-vpn-01
fly ips list -a elenakalab80-vpn-01
fly secrets set SS_HOST="ВАШ_IPV4_БЕЗ_КАВЫЧЕК_ЕСЛИ_НУЖНО" -a elenakalab80-vpn-01
fly deploy --depot=false
```

После этого в логах хост в `ss://` станет **IP**, а не `fly.dev`. Снова скопируйте **новую** строку `ss://` в Outline.
