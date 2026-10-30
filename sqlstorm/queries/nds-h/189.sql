WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS rank_cust
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderstatus
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        l.l_orderkey, o.o_orderstatus
)
SELECT 
    p.p_name,
    p.p_type,
    COALESCE(supp.total_avail_qty, 0) AS total_available_quantity,
    COALESCE(supp.avg_supply_cost, 0) AS average_supply_cost,
    cnt.n_name AS supplier_nation,
    CASE 
        WHEN RANK() OVER (ORDER BY o.total_order_value DESC) <= 10 THEN 'Top 10 Orders'
        ELSE 'Other Orders'
    END AS order_category
FROM 
    part p
LEFT JOIN 
    SupplierPart supp ON p.p_partkey = supp.ps_partkey
LEFT JOIN 
    HighValueOrders o ON supp.ps_suppkey = o.l_orderkey
LEFT JOIN 
    CustomerNation cnt ON o.l_orderkey = cnt.c_custkey
WHERE 
    p.p_retailprice BETWEEN 100 AND 1000
ORDER BY 
    total_available_quantity DESC, 
    p.p_name;