#!/bin/bash

# Script pour lancer la Step Function de refresh EFS

# Fonction d'aide pour afficher l'utilisation du script
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -n, --name NAME       Nom de la Step Function (obligatoire)"
  echo "  -i, --input FILE      Fichier JSON d'entrée (obligatoire)"
  echo "  -p, --profile PROFILE Profil AWS à utiliser (optionnel)"
  echo "  -r, --region REGION   Région AWS (optionnel, par défaut: eu-west-3)"
  echo "  -h, --help            Afficher cette aide"
  echo ""
  echo "Exemples:"
  echo "  $0 --name RefreshEnvEfsKamorionPreprod --input efs_refresh_input.json"
  echo "  $0 --name RefreshEnvEfsKamorionPreprod --input efs_refresh_input.json --profile my-profile --region eu-west-1"
  exit 1
}

# Valeurs par défaut
STEP_FUNCTION_NAME=""
INPUT_FILE=""
AWS_PROFILE=""
AWS_REGION="eu-west-3"

# Traitement des arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--name)
      STEP_FUNCTION_NAME="$2"
      shift 2
      ;;
    -i|--input)
      INPUT_FILE="$2"
      shift 2
      ;;
    -p|--profile)
      AWS_PROFILE="$2"
      shift 2
      ;;
    -r|--region)
      AWS_REGION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Option inconnue: $1"
      usage
      ;;
  esac
done

# Vérification des arguments obligatoires
if [[ -z "$STEP_FUNCTION_NAME" ]]; then
  echo "Erreur: Le nom de la Step Function est obligatoire"
  usage
fi

if [[ -z "$INPUT_FILE" ]]; then
  echo "Erreur: Le fichier d'entrée est obligatoire"
  usage
fi

# Vérification de l'existence du fichier d'entrée
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Erreur: Le fichier d'entrée '$INPUT_FILE' n'existe pas"
  exit 1
fi

# Construction de la commande AWS CLI
AWS_CMD="aws stepfunctions start-execution"

# Ajout du profil si spécifié
if [[ -n "$AWS_PROFILE" ]]; then
  AWS_CMD="$AWS_CMD --profile $AWS_PROFILE"
fi

# Ajout de la région
AWS_CMD="$AWS_CMD --region $AWS_REGION"

# Récupération de l'ARN de la Step Function
echo "Récupération de l'ARN de la Step Function $STEP_FUNCTION_NAME..."
STEP_FUNCTION_ARN=$(aws stepfunctions list-state-machines --region $AWS_REGION --output json | jq -r ".stateMachines[] | select(.name == \"$STEP_FUNCTION_NAME\") | .stateMachineArn")

if [[ -z "$STEP_FUNCTION_ARN" ]]; then
  echo "Erreur: Impossible de trouver l'ARN de la Step Function $STEP_FUNCTION_NAME"
  exit 1
fi

echo "ARN de la Step Function: $STEP_FUNCTION_ARN"

# Lecture du contenu du fichier d'entrée
INPUT_CONTENT=$(cat "$INPUT_FILE")

# Lancement de la Step Function
echo "Lancement de la Step Function avec le fichier d'entrée $INPUT_FILE..."
EXECUTION_RESULT=$(eval "$AWS_CMD --state-machine-arn $STEP_FUNCTION_ARN --input '$INPUT_CONTENT'")

if [[ $? -ne 0 ]]; then
  echo "Erreur lors du lancement de la Step Function"
  exit 1
fi

# Extraction de l'ARN de l'exécution
EXECUTION_ARN=$(echo $EXECUTION_RESULT | jq -r '.executionArn')
echo "Exécution lancée avec succès. ARN de l'exécution: $EXECUTION_ARN"

# Affichage du lien vers la console AWS
ACCOUNT_ID=$(echo $STEP_FUNCTION_ARN | cut -d':' -f5)
CONSOLE_URL="https://$AWS_REGION.console.aws.amazon.com/states/home?region=$AWS_REGION#/executions/details/$EXECUTION_ARN"
echo "Vous pouvez suivre l'exécution dans la console AWS: $CONSOLE_URL"

exit 0
