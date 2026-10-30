
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
), 
TopCustomerOrders AS (
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
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
)
SELECT 
    TOC.c_name,
    TOC.total_spent,
    SO.p_name,
    SO.ps_supplycost,
    SO.ps_availqty
FROM 
    TopCustomerOrders TOC
LEFT JOIN 
    SupplierPartDetails SO ON TOC.c_custkey IN (
        SELECT DISTINCT 
            c.c_custkey 
        FROM 
            customer c 
        JOIN 
            orders o ON c.c_custkey = o.o_custkey 
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE 
            l.l_shipdate > DATE '1998-10-01' - INTERVAL '30' DAY
    )
WHERE 
    TOC.total_spent > 1000
ORDER BY 
    TOC.total_spent DESC, SO.ps_supplycost ASC
LIMIT 50;
