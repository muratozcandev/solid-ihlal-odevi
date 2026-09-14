abstract class ISiparisRepository {
void kaydet(String orderId, double tutar);
}

abstract class IOdemeYontemi {
void odemeYap(double tutar);
}

abstract class IKargoServisi {
void kargoGonder(String orderId, String adres);
}

abstract class IMailServisi {
void mailGonder(String email, String mesaj);
}

abstract class ISmsServisi {
void smsGonder(String tel, String mesaj);
}

abstract class IFaturaServisi {
void faturaYazdir(String orderId);
}

abstract class IIndirim {
double uygula(double tutar);        // 	Interface Segregation Principle sorunu düzenlediğimiz yer
}


class Urun {
final String id;
final String ad;
final double fiyat;
int stok;
final String tip;

Urun(
this.id,
this.ad,
this.fiyat,
this.stok,
this.tip,
);
}

class FizikselUrun extends Urun {
FizikselUrun(
String id,
String ad,
double fiyat,
int stok,
) : super(id, ad, fiyat, stok, "FIZIKSEL");
}

class DijitalUrun extends Urun {
DijitalUrun(
String id,
String ad,
double fiyat,
int stok,
) : super(id, ad, fiyat, stok, "DIJITAL");
}


class SqliteVeritabani implements ISiparisRepository {            // S -> 	Single Responsibility Principle -> düzenlediğimiz yer
@override
void kaydet(String orderId, double tutar) {
print(
"DB calistirildi: "
"INSERT INTO siparisler VALUES ('$orderId', $tutar)",
);
}
}


class KrediKartiOdeme implements IOdemeYontemi {            // O -> Open/Closed Principle -> düzenlediğimiz yer
@override
void odemeYap(double tutar) {
print("$tutar TL Kredi kartindan POS ile cekildi.");
}
}

class HavaleOdeme implements IOdemeYontemi {
@override
void odemeYap(double tutar) {
print("$tutar TL Havale kontrol edildi.");
}
}

class KapidaOdeme implements IOdemeYontemi {
@override
void odemeYap(double tutar) {
print(
"$tutar TL Kapida odeme tahsil edilecek "
"(Komisyon +15 TL).",
);
}
}

class CryptoOdeme implements IOdemeYontemi {
@override
void odemeYap(double tutar) {
print("$tutar TL USDT transferi onaylandi.");    // O -> Open/Closed Principle -> düzenlediğimiz yer
}
}


class SmtpMailServisi implements IMailServisi {
@override
void mailGonder(String email, String mesaj) {
print("SMTP Mail gonderildi: $email");
}
}

class NetgsmSmsServisi implements ISmsServisi {
@override
void smsGonder(String tel, String mesaj) {
print("SMS iletildi: $tel");
}
}

class MngKargoServisi implements IKargoServisi {
@override
void kargoGonder(String orderId, String adres) {
print("MNG Kargo takip fis basildi: $adres");
}
}

class PdfFaturaServisi implements IFaturaServisi {
@override
void faturaYazdir(String orderId) {
print("Fatura PDF cikarildi: $orderId");
}
}


class IndirimYok implements IIndirim {
@override
double uygula(double tutar) {
return tutar;
}
}

class Indirim10 implements IIndirim {
@override
double uygula(double tutar) {
return tutar * 0.90;
}
}

class Yaz20Indirimi implements IIndirim {
@override
double uygula(double tutar) {
return tutar * 0.80;
}
}

class Sepette50Indirimi implements IIndirim {
@override
double uygula(double tutar) {
return tutar - 50;
}
}                                                        // S -> 	Single Responsibility Principle -> düzenlediğimiz yer

----

class SiparisServisi {
final ISiparisRepository repository;
final IOdemeYontemi odemeYontemi;
final IKargoServisi kargoServisi;
final IMailServisi mailServisi;
final ISmsServisi smsServisi;
final IFaturaServisi faturaServisi;
final IIndirim indirim;

SiparisServisi({
required this.repository,
required this.odemeYontemi,
required this.kargoServisi,
required this.mailServisi,
required this.smsServisi,
required this.faturaServisi,
required this.indirim,
});

void siparisTamamla({
required String orderId,
required List<Urun> sepet,
required String musteriAdi,
required String email,
required String tel,
required String adres,
}) {
double toplam = _urunToplaminiHesapla(sepet);

toplam = indirim.uygula(toplam);

final double kdv = toplam * 0.20;
final double sonTutar = toplam + kdv;

odemeYontemi.odemeYap(sonTutar);
repository.kaydet(orderId, sonTutar);
faturaServisi.faturaYazdir(orderId);

mailServisi.mailGonder(
  email,
  "Sayin $musteriAdi, "
  "siparisiniz alindi. Tutar: $sonTutar TL",
);

smsServisi.smsGonder(
  tel,
  "Siparisiniz onaylandi: $orderId",
);

kargoServisi.kargoGonder(
  orderId,
  adres,
);


}

double _urunToplaminiHesapla(List<Urun> sepet) {
double toplam = 0;

for (final urun in sepet) {
  if (urun.stok <= 0) {
    throw Exception("${urun.ad} tukenmis!");
  }

  toplam += urun.fiyat;

  if (urun is FizikselUrun) {
    toplam += 29.90;
  }

  urun.stok--;
}

return toplam;


}
}


void main() {
final siparisci = SiparisServisi(
repository: SqliteVeritabani(),
odemeYontemi: KrediKartiOdeme(),
kargoServisi: MngKargoServisi(),
mailServisi: SmtpMailServisi(),
smsServisi: NetgsmSmsServisi(),
faturaServisi: PdfFaturaServisi(),
indirim: Indirim10(),
);

final urun1 = FizikselUrun(
"1",
"Kablosuz Mouse",
450.0,
5,
);

final urun2 = DijitalUrun(
"2",
"Flutter Kursu E-Kitap",
150.0,
100,
);

final sepet = <Urun>[
urun1,
urun2,
];

siparisci.siparisTamamla(
orderId: "SP-9921",
sepet: sepet,
musteriAdi: "Selahaddin",
email: "selahaddin@kodvance.com",
tel: "05551112233",
adres: "Kadikoy / Istanbul",
);
}