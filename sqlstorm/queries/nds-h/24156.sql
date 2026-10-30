
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS brand_count
    FROM 
        part p
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        (CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown' 
            WHEN s.s_acctbal > 10000 THEN 'High Value Supplier' 
            ELSE 'Standard Supplier' 
         END) AS supplier_type
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
EligibleParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 0 AND AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    np.n_name AS nation_name,
    p.p_name AS part_name,
    p.p_brand,
    p.p_retailprice,
    cus.c_name AS customer_name,
    cus.total_orders,
    cus.total_spent,
    s.s_name AS supplier_name,
    COALESCE(hvs.supplier_type, 'No Type') AS supplier_type,
    COALESCE(ep.total_avail_qty, 0) AS available_quantity,
    COALESCE(ep.avg_supply_cost, 0) AS average_supply_cost
FROM 
    RankedParts p
JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation np ON np.n_nationkey = s.s_nationkey
JOIN 
    CustomerOrderSummary cus ON cus.c_custkey = (SELECT DISTINCT c.c_custkey FROM customer c WHERE c.c_name LIKE '%a%' LIMIT 1)
LEFT JOIN 
    HighValueSuppliers hvs ON hvs.s_suppkey = s.s_suppkey
LEFT JOIN 
    EligibleParts ep ON ep.ps_partkey = p.p_partkey
WHERE 
    (p.rank <= 5 OR (p.brand_count > 10 AND p.p_retailprice < 50))
    AND s.s_acctbal IS NOT NULL
ORDER BY 
    p.p_retailprice DESC, cus.total_spent ASC, np.n_name;
