WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        n.n_name AS nation_name,
        CONCAT(s.s_name, ' - ', n.n_name, ' - ', s.s_address) AS supplier_info,
        CASE 
            WHEN LENGTH(s.s_comment) > 50 THEN SUBSTRING(s.s_comment FROM 1 FOR 50) || '...' 
            ELSE s.s_comment 
        END AS truncated_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), OrderedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(o.o_orderkey) AS num_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
), BenchmarkData AS (
    SELECT 
        sd.supplier_info,
        oc.c_name,
        ROUND(AVG(oc.total_spent), 2) AS avg_spent,
        COUNT(DISTINCT oc.o_orderkey) AS total_orders,
        MAX(sd.truncated_comment) AS longest_comment
    FROM 
        SupplierDetails sd
    JOIN 
        OrderedCustomers oc ON sd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE '%brass%') LIMIT 1)
    GROUP BY 
        sd.supplier_info, oc.c_name
)
SELECT 
    *,
    CONCAT('Supplier: ', supplier_info, ', Customer: ', c_name, ', Average Spend: $', avg_spent, ', Total Orders: ', total_orders, ', Longest Comment: ', longest_comment) AS benchmark_output
FROM 
    BenchmarkData
ORDER BY 
    avg_spent DESC
LIMIT 10;
