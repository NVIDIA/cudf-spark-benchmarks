WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationalData AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    sd.s_name AS supplier_name,
    nd.n_name AS nation_name,
    nd.region_name,
    od.total_order_value,
    sd.total_supply_cost,
    sd.parts_supplied,
    od.line_item_count,
    CASE 
        WHEN od.total_order_value IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    CONCAT(nd.region_name, ' - ', nd.n_name, ' - ', sd.s_name) AS composite_detail
FROM 
    SupplierDetails sd
LEFT JOIN 
    OrderDetails od ON sd.s_suppkey = od.o_orderkey
JOIN 
    NationalData nd ON sd.s_suppkey = nd.n_nationkey
WHERE 
    sd.total_supply_cost > (
        SELECT AVG(total_supply_cost) FROM SupplierDetails
    ) OR nd.total_customers > 100
ORDER BY 
    total_order_value DESC NULLS LAST
LIMIT 100;
