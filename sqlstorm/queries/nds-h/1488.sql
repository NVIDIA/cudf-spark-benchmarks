WITH TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_partkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    sd.s_name AS supplier_name,
    ts.total_revenue,
    ts.total_quantity,
    COALESCE(sd.s_acctbal, 0) AS supplier_account_balance,
    (SELECT 
         COUNT(DISTINCT o.o_orderkey) 
     FROM 
         orders o
     JOIN 
         lineitem li ON o.o_orderkey = li.l_orderkey 
     WHERE 
         li.l_partkey = p.p_partkey AND 
         o.o_orderstatus = 'F') AS num_fulfilling_orders
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    TotalSales ts ON p.p_partkey = ts.l_partkey
WHERE 
    p.p_size > 10 AND 
    (p.p_retailprice BETWEEN 100 AND 500 OR p.p_comment IS NOT NULL)
ORDER BY 
    total_revenue DESC NULLS LAST
LIMIT 100;
