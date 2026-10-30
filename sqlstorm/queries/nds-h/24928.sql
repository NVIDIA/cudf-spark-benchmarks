WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1998-01-01'
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) / NULLIF(SUM(ps.ps_availqty), 0) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal > 0 THEN 'Positive Balance' 
            WHEN c.c_acctbal < 0 THEN 'Negative Balance' 
            ELSE 'Zero Balance'
        END AS balance_status
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS returned_sales,
    AVG(ps.avg_supply_cost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS completed_orders
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customernation c ON c.nation_name = n.n_name
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey AND o.o_orderstatus = 'F'
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupplierstats ps ON ps.ps_partkey = l.l_partkey
GROUP BY 
    r.r_name
HAVING 
    SUM(CASE WHEN c.balance_status = 'Negative Balance' THEN 1 ELSE 0 END) > 0
ORDER BY 
    returned_sales DESC, customer_count ASC
LIMIT 10 OFFSET 5;