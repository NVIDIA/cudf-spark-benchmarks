
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
), OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        SUM(l.l_extendedprice) AS total_line_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON l.l_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    o.o_orderkey,
    COALESCE(co.c_name, 'Unknown Customer') AS customer_name,
    oli.total_revenue,
    COALESCE(s.total_supply_cost, 0) AS supplier_cost,
    ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.order_rank) AS order_line_index
FROM 
    RankedOrders o
LEFT JOIN 
    OrderLineItems oli ON o.o_orderkey = oli.l_orderkey
LEFT JOIN 
    CustomerOrders co ON o.o_orderkey = co.c_custkey
LEFT JOIN 
    SupplierDetails s ON oli.l_orderkey = s.s_suppkey
WHERE 
    (o.o_totalprice > 1000 OR s.total_supply_cost IS NOT NULL)
    AND (o.o_orderdate IS NOT NULL OR (co.total_orders < 10 AND co.total_spent IS NOT NULL))
ORDER BY 
    o.o_orderkey, oli.total_revenue DESC, supplier_cost ASC;
