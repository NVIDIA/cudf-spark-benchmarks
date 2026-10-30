WITH benchmark AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        SUM(l.l_discount) AS total_discount,
        AVG(s.s_acctbal) AS avg_supplier_balance,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    COUNT(*) AS total_benchmarks, 
    SUM(total_discount) AS grand_total_discount, 
    AVG(avg_supplier_balance) AS overall_avg_supplier_balance, 
    SUM(total_customers) AS total_customers_count
FROM 
    benchmark;
