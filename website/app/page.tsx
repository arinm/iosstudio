import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import PhoneShowcase from "@/components/PhoneShowcase";
import FeatureWidget from "@/components/FeatureWidget";
import FeatureAuto from "@/components/FeatureAuto";
import FeatureCustomize from "@/components/FeatureCustomize";
import FeatureTemplates from "@/components/FeatureTemplates";
import HowItWorks from "@/components/HowItWorks";
import FAQ from "@/components/FAQ";
import CTA from "@/components/CTA";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main>
      <Navbar />
      <Hero />
      <PhoneShowcase />
      <FeatureWidget />
      <FeatureAuto />
      <FeatureCustomize />
      <FeatureTemplates />
      <HowItWorks />
      <FAQ />
      <CTA />
      <Footer />
    </main>
  );
}
