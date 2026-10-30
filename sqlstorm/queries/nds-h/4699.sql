WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey
),
PartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.supplier_count,
        ps.total_supplycost
    FROM 
        part p
    JOIN 
        PartSuppliers ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100.00 AND ps.supplier_count > 5
)
SELECT 
    r.r_name,
    SUM(ho.total_spent) AS total_spent_by_region,
    COUNT(DISTINCT ho.c_custkey) AS unique_customers,
    AVG(hp.p_retailprice) AS avg_high_value_price
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders ho ON c.c_custkey = ho.c_custkey
LEFT JOIN 
    HighValueParts hp ON ho.total_orders > 5 
WHERE 
    ho.total_spent IS NOT NULL OR hp.p_partkey IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_spent_by_region DESC;