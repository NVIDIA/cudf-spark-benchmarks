WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopCustomers AS (
    SELECT 
        rc.o_orderkey,
        rc.o_orderdate,
        rc.o_totalprice,
        rc.c_name,
        rc.c_acctbal
    FROM 
        RankedOrders rc
    WHERE 
        rc.rank <= 10
),
SalesData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        TopCustomers tc ON l.l_orderkey = tc.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    sd.p_name,
    sd.total_sales,
    COUNT(DISTINCT tc.o_orderkey) AS order_count
FROM 
    SalesData sd
JOIN 
    TopCustomers tc ON sd.total_sales > 1000
GROUP BY 
    sd.p_name, sd.total_sales
ORDER BY 
    sd.total_sales DESC, order_count DESC;