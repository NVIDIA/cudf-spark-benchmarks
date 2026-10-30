WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_acctbal IS NOT NULL) 
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
        AND l.l_discount BETWEEN 0.05 AND 0.1
    GROUP BY 
        o.o_orderkey 
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierOrderInfo AS (
    SELECT 
        ps.ps_suppkey,
        ps.ps_partkey,
        l.l_orderkey,
        COALESCE(p.p_name, 'Unknown Part') AS part_name,
        CASE 
            WHEN l.l_quantity IS NULL THEN 'No Quantity'
            ELSE CAST(l.l_quantity AS STRING)
        END AS quantity_str,
        RANK() OVER (PARTITION BY ps.ps_suppkey ORDER BY ps.ps_supplycost) AS supply_rank
    FROM 
        partsupp ps
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT n.n_nationkey) AS nations_count,
    SUM(CASE WHEN so.l_orderkey IS NOT NULL THEN 1 ELSE 0 END) AS orders_count,
    AVG(COALESCE(so.supply_rank, 0)) AS average_supply_rank,
    MAX(hv.total_revenue) AS max_order_revenue
FROM 
    region r 
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = n.n_nationkey
LEFT JOIN 
    SupplierOrderInfo so ON rs.s_suppkey = so.ps_suppkey
LEFT JOIN 
    HighValueOrders hv ON so.l_orderkey = hv.o_orderkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1 
    AND MAX(hv.total_revenue) IS NOT NULL
ORDER BY 
    region DESC, nations_count ASC;
