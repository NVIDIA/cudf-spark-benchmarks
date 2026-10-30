
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    sd.s_name AS supplier_name,
    sd.nation_name,
    SUM(co.o_totalprice) AS total_order_value,
    SUM(sd.total_supply_cost) AS total_supply_cost,
    AVG(co.lineitem_count) AS avg_lineitem_per_order,
    COUNT(DISTINCT co.o_orderkey) AS unique_orders
FROM 
    SupplierDetails sd
LEFT JOIN 
    CustomerOrders co ON sd.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
        )
        LIMIT 1
    )
GROUP BY 
    sd.s_name, sd.nation_name
ORDER BY 
    total_order_value DESC, avg_lineitem_per_order DESC
LIMIT 10;
