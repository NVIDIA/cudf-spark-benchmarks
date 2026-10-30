WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
HighValueLineItems AS (
    SELECT 
        li.l_orderkey,
        li.l_partkey,
        li.l_extendedprice,
        li.l_discount,
        li.l_tax,
        p.p_name,
        s.s_name,
        s.s_acctbal
    FROM 
        lineitem li
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON li.l_partkey = p.p_partkey
    WHERE 
        li.l_extendedprice * (1 - li.l_discount) > 1000
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS TotalRevenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem lo ON o.o_orderkey = lo.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    SUM(hr.l_extendedprice * (1 - hr.l_discount)) AS TotalHighValueSales,
    COUNT(DISTINCT hr.l_orderkey) AS UniqueHighValueOrders,
    COUNT(DISTINCT cr.c_custkey) AS ActiveCustomers,
    AVG(cr.TotalRevenue) AS AvgCustomerRevenue
FROM 
    HighValueLineItems hr
JOIN 
    supplier s ON hr.s_name = s.s_name
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    CustomerRevenue cr ON hr.l_orderkey = cr.c_custkey
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    TotalHighValueSales DESC;