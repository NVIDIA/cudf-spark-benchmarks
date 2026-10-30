WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        ps.ps_supplycost,
        ps.ps_availqty,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderdate
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_name LIKE '%rubber%'
        AND s.s_comment NOT LIKE '%small%'
        AND c.c_acctbal > 100.00
),
AggregatedInfo AS (
    SELECT 
        p_brand,
        COUNT(DISTINCT supplier_name) AS distinct_supplier_count,
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM 
        PartSupplierInfo
    GROUP BY 
        p_brand
)
SELECT 
    p_brand,
    distinct_supplier_count,
    total_supply_cost,
    CASE 
        WHEN total_supply_cost > 100000 THEN 'High'
        WHEN total_supply_cost BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low' 
    END AS cost_category
FROM 
    AggregatedInfo
ORDER BY 
    cost_category DESC, distinct_supplier_count DESC;
