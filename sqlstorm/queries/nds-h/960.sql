WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F' AND
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1' YEAR
),
SupplierAggregate AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
OrderLineItem AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    COALESCE(SA.total_supply_cost, 0) AS supplier_cost,
    OLI.net_price,
    CASE 
        WHEN r.order_rank <= 5 THEN 'Top Order'
        ELSE 'Regular Order' 
    END AS order_category
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierAggregate SA ON r.o_orderkey = SA.ps_suppkey
LEFT JOIN 
    OrderLineItem OLI ON r.o_orderkey = OLI.l_orderkey
WHERE 
    r.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) OR 
    r.o_orderdate < cast('1998-10-01' as date) - INTERVAL '6' MONTH
ORDER BY 
    r.o_totalprice DESC, r.o_orderdate ASC;