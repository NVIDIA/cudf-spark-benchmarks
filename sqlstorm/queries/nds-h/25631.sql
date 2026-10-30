
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_acctbal, s.s_nationkey
),
CustomerSegmentAnalysis AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
),
SupplierPerformance AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        ss.s_name,
        ss.total_available,
        cs.total_spent,
        cs.total_orders
    FROM 
        RankedSuppliers ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        CustomerSegmentAnalysis cs ON ss.s_suppkey = cs.c_custkey
    WHERE 
        ss.rank <= 5
)
SELECT 
    region,
    nation,
    s_name,
    total_available,
    total_spent,
    total_orders,
    CASE 
        WHEN total_spent > 10000 THEN 'High Value'
        WHEN total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    SupplierPerformance
ORDER BY 
    region, nation, total_available DESC;
