
WITH SupplierRanked AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS account_rank,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name, 
        SUM(od.total_line_sales) AS total_spent,
        COUNT(DISTINCT od.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        OrderDetails od ON c.c_custkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sr.s_name,
    sr.account_rank,
    cs.c_name,
    cs.total_spent,
    cs.order_count,
    COALESCE(cs.total_spent / NULLIF(cs.order_count, 0), 0) AS avg_spent_per_order
FROM 
    SupplierRanked sr
LEFT JOIN 
    CustomerSales cs ON sr.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_retailprice > 100 
            ORDER BY p.p_retailprice DESC 
            LIMIT 1
        )
        LIMIT 1
    )
WHERE 
    sr.account_rank = 1
ORDER BY 
    sr.s_name ASC, cs.total_spent DESC;
