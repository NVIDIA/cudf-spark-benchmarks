WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        p.p_brand,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, p.p_brand
),
TopOrders AS (
    SELECT 
        cod.c_custkey,
        cod.c_name,
        cod.o_orderkey,
        cod.o_totalprice,
        cod.o_orderdate,
        cod.p_brand,
        cod.total_quantity
    FROM 
        CustomerOrderDetails cod
    JOIN 
        RankedOrders ro ON cod.o_orderkey = ro.o_orderkey 
    WHERE 
        ro.rn <= 10
)
SELECT 
    t.c_custkey,
    t.c_name,
    COUNT(t.o_orderkey) AS order_count,
    SUM(t.o_totalprice) AS total_spent,
    AVG(t.total_quantity) AS avg_quantity_per_order,
    MAX(t.o_orderdate) AS last_order_date
FROM 
    TopOrders t
GROUP BY 
    t.c_custkey, t.c_name
ORDER BY 
    total_spent DESC;