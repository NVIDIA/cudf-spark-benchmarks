
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
        c.c_custkey AS custkey,
        c.c_name AS name,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rnk
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > 0
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_quantity ELSE 0 END) AS returned_quantity,
    AVG(li.l_quantity) AS average_quantity_sold,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 10
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, n.n_name, r.r_name
HAVING 
    SUM(li.l_quantity) > 100
ORDER BY 
    returned_quantity DESC, average_quantity_sold ASC
LIMIT 10;
