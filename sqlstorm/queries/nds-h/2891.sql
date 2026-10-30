WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopCustomers AS (
    SELECT 
        r.r_name,
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name, c.c_nationkey
),
SupplierPartDetails AS (
    SELECT 
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, ps.ps_partkey, p.p_name
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    tc.r_name,
    s.p_name,
    s.total_available,
    od.revenue,
    od.item_count,
    ro.o_orderdate
FROM 
    TopCustomers tc
LEFT JOIN 
    SupplierPartDetails s ON tc.c_nationkey = s.ps_partkey
LEFT JOIN 
    OrderDetails od ON s.ps_partkey = od.l_orderkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey = od.l_orderkey
WHERE 
    tc.order_count > 5 AND 
    (s.total_available IS NULL OR s.total_available > 100)
ORDER BY 
    tc.r_name, od.revenue DESC;