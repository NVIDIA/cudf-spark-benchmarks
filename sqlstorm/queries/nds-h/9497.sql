WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        SUM(l.l_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, s.s_name
),
OrderDetails AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.supplier_name,
        ro.total_quantity,
        DENSE_RANK() OVER (ORDER BY ro.o_orderdate DESC) AS order_rank
    FROM 
        RankedOrders ro
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    od.o_totalprice,
    od.c_name,
    od.supplier_name,
    od.total_quantity
FROM 
    OrderDetails od
WHERE 
    od.order_rank <= 10
ORDER BY 
    od.o_totalprice DESC, od.o_orderdate;
