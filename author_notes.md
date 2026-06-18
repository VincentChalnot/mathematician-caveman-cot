# 📝 NOTES D'AUTEUR — Points d'attention pour la version finale

**[À VÉRIFIER AVANT PUBLICATION]** — Le problème gsm8k-12 (arbre à citrons, target=13) échoue sur TOUTES les conditions
sauf caveman-CoT. C'est peut-être une question mal formulée dans le dataset ou un problème d'arrondi ambigu. Vérifier
manuellement et mentionner si c'est une anomalie du benchmark.

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
