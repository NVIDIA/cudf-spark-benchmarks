WITH  Order_Summary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
Nation_Supplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT
    ps.ps_partkey,
    p.p_name,
    p.p_brand,
    ps.ps_availqty,
    ps.ps_supplycost,
    ns.n_name AS supplier_nation,
    ns.total_suppliers,
    ns.total_account_balance,
    SUM(os.total_sales) OVER (PARTITION BY p.p_partkey) AS total_sales_for_part,
    CASE 
        WHEN p.p_size IS NULL THEN 'Size Unknown' 
        ELSE CAST(p.p_size AS STRING) 
    END AS part_size_string,
    COALESCE(NULLIF(p.p_comment, ''), 'No Comments') AS comment_status,
    RANK() OVER (PARTITION BY ns.n_name ORDER BY ns.total_account_balance DESC) AS supplier_rank
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    Nation_Supplier ns ON p.p_brand = ns.n_name
LEFT JOIN 
    Order_Summary os ON ps.ps_partkey = os.o_orderkey
WHERE 
    (p.p_retailprice BETWEEN 0 AND 100) AND
    (os.total_sales IS NOT NULL OR ns.total_suppliers > 0)
ORDER BY 
    total_sales_for_part DESC, 
    ns.total_suppliers DESC;