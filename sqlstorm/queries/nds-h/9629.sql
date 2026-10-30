
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS regional_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 10000
), BestCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 5000
), OrdersWithItems AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), Summary AS (
    SELECT 
        b.c_custkey,
        b.c_name,
        r.region_name,
        r.regional_rank,
        o.o_orderkey,
        o.o_orderdate,
        o.item_count,
        o.total_value
    FROM 
        BestCustomers b
    JOIN 
        RankedSuppliers r ON r.regional_rank = 1
    JOIN 
        OrdersWithItems o ON b.c_custkey = o.o_orderkey
)
SELECT 
    s.c_custkey AS cust_key,
    s.c_name,
    s.region_name,
    s.o_orderkey,
    s.o_orderdate,
    s.item_count,
    s.total_value
FROM 
    Summary s
WHERE 
    s.total_value > 10000
ORDER BY 
    s.o_orderdate DESC, 
    s.total_value DESC
LIMIT 50;
