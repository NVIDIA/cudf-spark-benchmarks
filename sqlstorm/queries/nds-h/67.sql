WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1997-10-01'
), 
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000.00
), 
part_supplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(pi.total_available, 0) AS total_available,
    COALESCE(pi.avg_supply_cost, 0) AS avg_supply_cost,
    s.s_name AS supplier_name,
    s.s_acctbal AS supplier_acctbal,
    CASE 
        WHEN o.o_orderkey IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS has_orders
FROM 
    part p
LEFT JOIN 
    part_supplier pi ON p.p_partkey = pi.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    ranked_orders o ON l.l_orderkey = o.o_orderkey AND o.order_rank <= 5
LEFT JOIN 
    supplier_info s ON l.l_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 50.00
    AND (p.p_comment NOT LIKE '%defective%' OR p.p_container IS NULL)
ORDER BY 
    p.p_partkey
LIMIT 100;