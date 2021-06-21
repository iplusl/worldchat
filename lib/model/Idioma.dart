class Idioma {
  final int id;
  final String nome;
  final String bandeira;
  final String codIdioma;

  Idioma(this.id, this.nome, this.bandeira, this.codIdioma);

  static List<Idioma> listaIdiomas(){
    return <Idioma>[
      Idioma(1, "English", "🇺🇸", "en"),
      Idioma(2, "Español", "🇪🇸", "es"),
      Idioma(3, "Português", "🇧🇷", "pt"),
    ];
  }
}