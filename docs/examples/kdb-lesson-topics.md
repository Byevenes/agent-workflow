# Temas y repositorios

Pégala en el KDB del proyecto cliente. Un humano la revisa antes. No la copies a un repo cliente desde el repo de flujo.

Un bloque `topics` mapea un tema a las palabras que lo nombran y al repositorio que hay que tener para concluir sobre él. Los campos van separados por un tabulador: tema, palabras en una lista separada por comas, y el nombre del repositorio.

```topics
sesion	login,otp,lockout	auth-spi
```

Si el borrador nombra una de esas palabras y ese repositorio no está entre los presentes, `scripts/check-topic-repos.sh` exige que cada línea con la palabra sea una pregunta `Qn. … repo-ausente: <repo>`. Una conclusión en cualquier otra forma falla.
