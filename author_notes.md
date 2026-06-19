# 📝 NOTES D'AUTEUR — Points d'attention pour la version finale

**[RÉSOLU — GSM8K Platinum]** — Le problème gsm8k-12 (arbre à citrons, target=13) échoue sur TOUTES les conditions
sauf caveman-CoT. Ce problème a été identifié comme défectueux dans GSM8K Platinum (madrylab/gsm8k-platinum) et est
maintenant marqué `redacted: true` dans tous les fichiers de résultats. Il est exclu du calcul du score.

**[SECTION À AJOUTER]** — Résultats LiveCodeBench / HumanEval+ une fois disponibles. C'est le vrai test de
généralisation.

**[COÛT RÉEL]** — Run complet estimé à ~18€ (voir reference.md pour le détail). À confirmer avec la facture OpenRouter
réelle. Ajouter le chiffre à l'article rend le benchmark plus concret et reproductible.

**[REPRENDRE]** — La distinction "version forte vs version faible" de l'hypothèse caveman (est-ce que ça change le
raisonnement ou seulement sa projection ?) mérite d'être développée dans la section mécanismes. C'est le point le plus
intéressant théoriquement.

**[AUDIENCE]** — L'article cible des développeurs qui font tourner des agents en prod, pas des chercheurs ML. Garder le
ton praticien, éviter le jargon académique excessif, insister sur les implications coût/latence.

**[REPRODUCIBILITÉ]** — Inclure un lien vers le repo GitHub avec les prompts exacts et le config.yaml. La
reproductibilité est un argument de crédibilité fort.
