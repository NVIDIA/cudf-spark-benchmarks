
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL
        )
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '3 months' AND
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        SUM(l.l_discount) < 0.1
), 
NationSummary AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
    HAVING 
        SUM(s.s_acctbal) IS NOT NULL
)

SELECT 
    n.n_name,
    ns.customer_count,
    ns.total_acctbal,
    COALESCE(rs.s_name, 'No Suppliers') AS top_supplier,
    HVO.net_value,
    CASE 
        WHEN HVO.net_value > ns.total_acctbal THEN 'High'
        ELSE 'Low'
    END AS value_status
FROM 
    NationSummary ns
JOIN 
    nation n ON ns.n_nationkey = n.n_nationkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1
LEFT JOIN 
    HighValueOrders HVO ON ns.total_acctbal > 10000
ORDER BY 
    n.n_name, ns.customer_count DESC
LIMIT 10 OFFSET 5;
