WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), RecentOrderDetails AS (
    SELECT 
        oo.o_orderkey,
        oo.o_orderdate,
        l.l_partkey,
        l.l_extendedprice,
        l.l_discount,
        p.p_name,
        p.p_brand,
        s.s_name AS supplier_name,
        s.s_nationkey
    FROM 
        RankedOrders oo
    JOIN 
        lineitem l ON oo.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        oo.OrderRank = 1
), TotalRevenue AS (
    SELECT 
        r.r_name AS region,
        SUM(rd.l_extendedprice * (1 - rd.l_discount)) AS revenue
    FROM 
        RecentOrderDetails rd
    JOIN 
        nation n ON rd.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    region,
    revenue
FROM 
    TotalRevenue
ORDER BY 
    revenue DESC
LIMIT 10;
