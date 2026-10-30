WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
), 
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), 
PopularProducts AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_partkey
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    r.o_orderstatus,
    c.c_name AS customer_name,
    p.p_name AS product_name,
    pp.total_quantity
FROM 
    RankedOrders r
JOIN 
    TopCustomers c ON r.o_orderkey = c.c_custkey
JOIN 
    PopularProducts pp ON pp.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE '%metal%' LIMIT 1)
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    r.rank_status <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;