<?php

namespace Playbloom\Satisfy\Controller;

use Playbloom\Satisfy\Http\ProcessResponse;
use Playbloom\Satisfy\Runner\SatisBuildRunner;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\IpUtils;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\Extension\Core\Type\SubmitType;

class SatisController extends AbstractProtectedController
{
    public function buildAction(): Response
    {
        $this->checkAccess();

        return $this->render('@PlaybloomSatisfy/satis_build.html.twig');
    }

    public function buildRepoAction(Request $request): Response
    {
        $this->checkAccess();

	$form = $this->createFormBuilder()
		->add('repository', TextType::class)
		->add('submit', SubmitType::class)
        	->getForm();

        return $this->render('@PlaybloomSatisfy/satis_build_repo.html.twig', ['form' => $form->createView()]);
    }

    public function buildRunAction(SatisBuildRunner $runner): Response
    {
        $this->checkAccess();
        $output = $runner->run();

        return ProcessResponse::createFromOutput($output);
    }

    public function buildRunRepoAction(Request $request): Response
    {
        $nginxDnsA = dns_get_record('momcorpfdc.nginx-balancer-http.services.ruhmesmeile.local', DNS_A);
        if ($request->getClientIp() === $nginxDnsA[0]["ip"]) {
                $this->checkAccess();
        } else {
                $this->validate($request);
        }

        $repository = $request->attributes->get('repository');
        $runner = $this->container->get(SatisBuildRunner::class);
        $output = $runner->runRepo(sprintf('ssh://git@bitbucket.ruhmesmeile.tools:7999/%s.git', $repository));

        return ProcessResponse::createFromOutput($output);
    }

    protected function validate(Request $request): void
    {
        $ip = $request->getClientIp();
        $trusted = [
            '10.1.55.0/24',
        ];

        if (!IpUtils::checkIp($ip, $trusted)) {
            throw new \InvalidArgumentException('Client IP address is not trusted');
        }
    }
}
