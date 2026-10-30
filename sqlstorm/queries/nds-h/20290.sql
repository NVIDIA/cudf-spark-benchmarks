WITH SupplierAggregation AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighCostSuppliers AS (
    SELECT 
        sa.s_suppkey,
        sa.total_cost,
        RANK() OVER (ORDER BY sa.total_cost DESC) AS rank_cost
    FROM 
        SupplierAggregation sa
    WHERE 
        sa.total_cost > (SELECT AVG(total_cost) FROM SupplierAggregation)
),
NationCustomerDetails AS (
    SELECT 
        n.n_name,
        c.c_custkey,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            ELSE 'Balance Available'
        END AS balance_status
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    ncd.n_name AS nation,
    ncd.balance_status,
    COALESCE(hc.total_cost, 0) AS supplier_cost,
    (CASE 
        WHEN ncd.c_acctbal IS NULL THEN 'Insufficient Funds'
        WHEN hc.total_cost IS NULL THEN 'No Suppliers'
        ELSE 'Sufficient Funds'
     END) AS funding_status
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    HighCostSuppliers hc ON ps.ps_suppkey = hc.s_suppkey
JOIN 
    NationCustomerDetails ncd ON ncd.c_custkey = ps.ps_partkey
WHERE 
    p.p_retailprice > 100
    OR (p.p_comment LIKE '%dull%' AND EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_discount > 0))
ORDER BY 
    p.p_name,
    funding_status DESC,
    ncd.balance_status;
