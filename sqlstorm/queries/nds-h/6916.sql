WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
)
SELECT 
    tro.o_orderkey,
    tro.o_orderdate,
    tro.total_revenue,
    sd.s_suppkey,
    sd.s_name,
    sd.s_acctbal,
    sd.ps_supplycost,
    sd.ps_availqty
FROM 
    TopRevenueOrders tro
JOIN 
    lineitem l ON tro.o_orderkey = l.l_orderkey
JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
ORDER BY 
    tro.total_revenue DESC, sd.s_acctbal DESC;
