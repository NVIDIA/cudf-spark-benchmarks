WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        co.total_spent,
        co.order_count,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
)
SELECT 
    pc.p_partkey,
    pc.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    MAX(s.s_acctbal) AS max_supplier_balance,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM 
    part pc
JOIN 
    partsupp ps ON pc.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND pc.p_size > 10
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
    AND EXISTS (
        SELECT 1
        FROM TopCustomers tc
        WHERE tc.c_custkey = l.l_orderkey AND tc.rank_spent <= 10
    )
GROUP BY 
    pc.p_partkey, pc.p_name, r.r_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_quantity DESC;