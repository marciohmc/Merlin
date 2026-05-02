import React, { useState, useEffect } from 'react';
import { Shield, Server, Database, Terminal, AlertTriangle, CheckCircle2, ExternalLink, Cpu } from 'lucide-react';
import { motion } from 'motion/react';

export default function App() {
  const [activeTab, setActiveTab ] = useState('overview');

  const setupFiles = [
    { name: 'Dockerfile', status: 'Pronto', detail: 'Base Debian 12-slim otimizada.' },
    { name: 'render.yaml', status: 'Pronto', detail: 'Configurado como Background Worker.' },
    { name: 'entrypoint.sh', status: 'Pronto', detail: 'Gestão de GOGC e RAM (512MB).' }
  ];

  return (
    <div className="min-h-screen bg-slate-950 text-slate-200 font-sans selection:bg-blue-500/30">
      {/* Header */}
      <header className="border-b border-white/5 bg-slate-900/50 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-600 rounded-lg shadow-lg shadow-blue-500/20">
              <Shield className="w-5 h-5 text-white" />
            </div>
            <h1 className="font-bold tracking-tight text-xl">Merlin C2 <span className="text-blue-400">DevSecOps Lab</span></h1>
          </div>
          <div className="flex items-center gap-4 text-xs font-medium uppercase tracking-widest text-slate-500">
            <span className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" /> Live Preview</span>
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6 py-12">
        <div className="grid lg:grid-cols-3 gap-8">
          
          {/* Status Column */}
          <div className="lg:col-span-1 space-y-6">
            <section className="bg-slate-900 border border-white/5 rounded-2xl p-6 shadow-xl">
              <h2 className="text-sm font-semibold text-slate-400 mb-4 flex items-center gap-2 uppercase tracking-wider">
                <Server className="w-4 h-4 text-blue-400" /> Configuração do Deploy
              </h2>
              <div className="space-y-4">
                {setupFiles.map((file) => (
                  <div key={file.name} className="flex items-start gap-3">
                    <CheckCircle2 className="w-5 h-5 text-green-500 mt-0.5 shrink-0" />
                    <div>
                      <p className="text-sm font-medium text-slate-200">{file.name}</p>
                      <p className="text-xs text-slate-500">{file.detail}</p>
                    </div>
                  </div>
                ))}
              </div>
            </section>

            <section className="bg-blue-600/10 border border-blue-500/20 rounded-2xl p-6">
              <div className="flex items-center gap-2 mb-3">
                <Cpu className="w-4 h-4 text-blue-400" />
                <h3 className="text-sm font-bold text-blue-400 uppercase tracking-wider">Otimização de RAM</h3>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed italic">
                "Configuramos GOGC=50 no entrypoint.sh para garantir que o coletor de lixo do Go mantenha o uso de memória abaixo dos 512MB do Render Free."
              </p>
            </section>
          </div>

          {/* Main Content Column */}
          <div className="lg:col-span-2 space-y-8">
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-slate-900 border border-white/5 rounded-2xl overflow-hidden shadow-2xl"
            >
              <div className="flex border-b border-white/5">
                <button 
                  onClick={() => setActiveTab('overview')}
                  className={`px-6 py-4 text-sm font-medium transition-colors ${activeTab === 'overview' ? 'text-blue-400 border-b-2 border-blue-400 bg-white/5' : 'text-slate-500 hover:text-slate-300'}`}
                >
                  Instruções de Deploy
                </button>
                <button 
                  onClick={() => setActiveTab('persistence')}
                  className={`px-6 py-4 text-sm font-medium transition-colors ${activeTab === 'persistence' ? 'text-blue-400 border-b-2 border-blue-400 bg-white/5' : 'text-slate-500 hover:text-slate-300'}`}
                >
                  Persistência & Rede
                </button>
              </div>

              <div className="p-8">
                {activeTab === 'overview' ? (
                  <div className="space-y-6">
                    <div className="prose prose-invert prose-sm max-w-none">
                      <p className="text-slate-400 text-base leading-relaxed">
                        Este ambiente está pronto para ser exportado e deployado no **Render.com**. 
                        Utilizamos o padrão de <strong className="text-slate-200">Blueprint (render.yaml)</strong> para garantir que todas as configurações de DevSecOps sejam aplicadas automaticamente.
                      </p>
                    </div>

                    <div className="bg-slate-950 rounded-xl p-6 border border-white/5 font-mono text-sm">
                      <div className="flex justify-between items-center mb-4">
                        <span className="text-slate-500 font-sans tracking-tight">Comando de Acesso (Via Render SSH)</span>
                        <Terminal className="w-4 h-4 text-slate-600" />
                      </div>
                      <div className="text-blue-400"># Acesse o servidor Merlin para interagir</div>
                      <div className="text-slate-300 mt-2">render ssh --app merlin-c2-server</div>
                      <div className="text-slate-300 mt-2">cd /opt/merlin && ./merlin-server</div>
                    </div>

                    <div className="flex items-start gap-4 p-4 bg-amber-500/10 border border-amber-500/20 rounded-xl">
                      <AlertTriangle className="w-5 h-5 text-amber-500 shrink-0 mt-0.5" />
                      <p className="text-xs text-amber-200/70 leading-relaxed">
                        <strong>Nota de Segurança:</strong> Ao rodar no Render como "Worker", o Merlin não recebe tráfego de entrada público por padrão. Se você precisar de beacons externos conectando, considere integrar um binário do <code>ngrok</code> ou <code>cloudflared</code> no Dockerfile.
                      </p>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-6">
                    <div className="bg-slate-950/50 rounded-xl p-6 border border-white/5">
                      <h4 className="font-bold flex items-center gap-2 mb-4">
                        <Database className="w-4 h-4 text-blue-400" /> Estratégia de Persistência
                      </h4>
                      <ul className="space-y-3 text-sm text-slate-400">
                        <li className="flex gap-2">
                          <span className="text-blue-400">•</span>
                          <span><strong>Render Free:</strong> O banco <code>merlin.db</code> é armazenado na pasta <code>/opt/merlin/data</code>, que é efêmera. No reboot, os dados resetam.</span>
                        </li>
                        <li className="flex gap-2">
                          <span className="text-blue-400">•</span>
                          <span><strong>Solução Recomendada:</strong> Adicione um <code>Disk</code> no seu <code>render.yaml</code> (requer plano pago) para persistir o <code>merlin.db</code>.</span>
                        </li>
                      </ul>
                    </div>

                    <div className="bg-slate-950/50 rounded-xl p-6 border border-white/5">
                      <h4 className="font-bold flex items-center gap-2 mb-4">
                        <ExternalLink className="w-4 h-4 text-blue-400" /> Rede (Túneis)
                      </h4>
                      <p className="text-sm text-slate-400 leading-relaxed">
                        Como Workers no Render não expõem conexões TCP/UDP diretamente à internet pública no plano gratuito, você deve usar um serviço de túnel. 
                        No seu ambiente de laboratório, você pode rodar o comando <code>./merlin-server</code> e em outra aba do SSH configurar um túnel para redirecionar a porta 443 do container.
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </motion.div>

            <footer className="text-center text-slate-600 text-xs">
              Configurado por Especialista DevSecOps • Merlin Server Latest • Render Protocol Optimized
            </footer>
          </div>
        </div>
      </main>
    </div>
  );
}
