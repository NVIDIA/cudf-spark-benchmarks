WITH RankedLineItems AS (
    SELECT 
        l_orderkey,
        l_partkey,
        l_suppkey,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY l_linenumber) AS rn
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1997-12-31'
),
TotalPricePerOrder AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price,
        COUNT(li.l_partkey) AS item_count
    FROM 
        orders o
    JOIN 
        RankedLineItems li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierStatistics AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerAverageOrderValue AS (
    SELECT 
        c.c_custkey,
        AVG(tp.total_price) AS average_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TotalPricePerOrder tp ON o.o_orderkey = tp.o_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ca.average_order_value) AS total_average_order_value,
    SUM(ss.supplied_parts) AS total_supplied_parts,
    SUM(ss.total_supply_cost) AS total_supply_cost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    CustomerAverageOrderValue ca ON c.c_custkey = ca.c_custkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierStatistics ss ON s.s_suppkey = ss.s_suppkey
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_average_order_value DESC;