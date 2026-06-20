output "eks_cluster_name"              { value = aws_eks_cluster.main.name }
output "eks_cluster_endpoint"          { value = aws_eks_cluster.main.endpoint }
output "eks_cluster_ca"                { value = aws_eks_cluster.main.certificate_authority[0].data }
output "eks_cluster_security_group_id" { value = aws_security_group.eks_cluster.id }
