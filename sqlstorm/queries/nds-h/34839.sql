WITH  sales_rank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS cust_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), 
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
),
customer_details AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        r.r_name,
        c.c_acctbal,
        COALESCE((
            SELECT COUNT(*) 
            FROM orders o 
            WHERE o.o_custkey = c.c_custkey
        ), 0) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        c.c_acctbal IS NOT NULL AND
        c.c_acctbal > (
             SELECT AVG(c_acctbal) 
             FROM customer
        )
)
SELECT 
    cd.c_custkey,
    cd.c_name,
    sr.total_spent,
    ps.p_name,
    ps.total_supplycost,
    cd.order_count,
    cd.r_name
FROM 
    customer_details cd
LEFT JOIN 
    sales_rank sr ON cd.c_custkey = sr.c_custkey
LEFT JOIN 
    part_supplier ps ON sr.cust_rank <= 3 AND sr.total_spent > ps.total_supplycost
WHERE 
    cd.order_count > 10
ORDER BY 
    cd.c_name, sr.total_spent DESC
LIMIT 100;