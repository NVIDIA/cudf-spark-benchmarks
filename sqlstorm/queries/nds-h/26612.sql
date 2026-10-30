WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_name, p.p_size, p.p_brand, p.p_type, 
           SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_brand LIKE 'Brand#%'
), RankedSuppliers AS (
    SELECT sp.s_name, sp.p_type, COUNT(*) AS part_count,
           ROW_NUMBER() OVER (PARTITION BY sp.p_type ORDER BY COUNT(*) DESC) AS rank
    FROM SupplierParts sp
    GROUP BY sp.s_name, sp.p_type
), CustomerOrders AS (
    SELECT c.c_name, SUM(o.o_totalprice) AS total_spent,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
)
SELECT r.s_name, r.p_type, r.part_count, c.c_name, c.total_spent
FROM RankedSuppliers r
JOIN CustomerOrders c ON r.rank <= 5
WHERE r.part_count > 10
ORDER BY r.p_type, c.total_spent DESC;
