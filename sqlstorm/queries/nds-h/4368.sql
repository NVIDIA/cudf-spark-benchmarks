
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_suppkey
    ORDER BY 
        total_supply_cost DESC
    LIMIT 5
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
DetailedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_extendedprice,
        l.l_discount,
        (l.l_extendedprice * (1 - l.l_discount)) AS discount_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < DATE '1998-10-01'
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(cs.total_spent) AS avg_customer_spent,
    SUM(dli.discount_price) AS total_discounted_sales,
    MAX(o.o_totalprice) AS max_order_total
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.ps_suppkey
JOIN 
    partsupp ps ON ts.ps_suppkey = ps.ps_suppkey
RIGHT JOIN 
    DetailedLineItems dli ON ps.ps_partkey = dli.l_partkey
JOIN 
    customer c ON c.c_custkey = (SELECT MIN(cust.c_custkey) FROM CustomerSummary cust WHERE cust.total_spent > 1000)
JOIN 
    orders o ON o.o_custkey = c.c_custkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    CustomerSummary cs ON cs.c_custkey = c.c_custkey
WHERE 
    dli.l_discount > 0.1
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_discounted_sales DESC;
