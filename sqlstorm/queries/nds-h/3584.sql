WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spend
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), HighValueSuppliers AS (
    SELECT 
        ps_partkey,
        COUNT(s_suppkey) AS supplier_count
    FROM 
        RankedSuppliers
    WHERE 
        rn <= 3
    GROUP BY 
        ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(hvs.supplier_count, 0) AS high_value_supplier_count,
    cp.total_orders,
    cp.total_spend,
    sp.total_supply_cost,
    CASE 
        WHEN cp.total_spend > 10000 THEN 'High'
        WHEN cp.total_spend BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS customer_segment,
    CONCAT('Part: ', p.p_name, ', Total Spend: ', COALESCE(cp.total_spend, 0)) AS summary
FROM 
    part p
LEFT JOIN 
    HighValueSuppliers hvs ON p.p_partkey = hvs.ps_partkey
LEFT JOIN 
    CustomerOrders cp ON cp.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY c.c_acctbal DESC LIMIT 1)
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice IS NOT NULL
ORDER BY 
    p.p_partkey;
