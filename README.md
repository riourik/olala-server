# olala-server

Image Docker de **Olala mini 7A1B** (OVHcloud), servi sur **processeur** par la
[version modifiée de llama.cpp d'OVHcloud](https://github.com/OVHai-LLM/llama.cpp),
avec un **modèle Unraid** pour l'installer comme n'importe quelle application.

- Adresse compatible OpenAI : `http://IP:8090/v1`
- Téléchargement automatique du modèle au premier démarrage
- Image reconstruite chaque lundi pour suivre les mises à jour d'OVHcloud

## Installation sur Unraid

1. Dans le terminal d'Unraid, installe le modèle :
   `wget -O /boot/config/plugins/dockerMan/templates-user/my-olala-server.xml https://raw.githubusercontent.com/riourik/olala-server/main/unraid/olala-server.xml`
   puis onglet **Docker** → **Add Container** → choisis **olala-server** dans **Template**.
2. Vérifie les réglages, puis **Apply**.
3. Le premier démarrage télécharge le modèle (environ 7 Go) : suis-le dans les **logs** du container.

## Brancher sur Hermes

```bash
hermes config set model.provider custom
hermes config set model.base_url http://IP-DE-TOWER:8090/v1
hermes config set model.default olala-mini
```

Attention : le contexte du modèle est limité à **32 768 tokens**. Il convient à des tâches
courtes (résumés, traduction, questions simples), pas au cerveau principal d'un agent.

## Réglages recommandés par OVHcloud

Température 0.8, top-p 0.9, top-k 40 (déjà appliqués par défaut).
Effort de réflexion par requête : `"reasoning_effort": "disabled" | "low" | "medium" | "high"`.

## Licence

Le modèle Olala est publié par OVHcloud sous licence Apache 2.0.
